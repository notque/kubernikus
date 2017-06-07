package operations

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"net/http"

	"github.com/go-openapi/runtime"

	"github.com/sapcc/kubernikus/pkg/api/models"
)

// ListAPIVersionsOKCode is the HTTP code returned for type ListAPIVersionsOK
const ListAPIVersionsOKCode int = 200

/*ListAPIVersionsOK OK

swagger:response listApiVersionsOK
*/
type ListAPIVersionsOK struct {

	/*
	  In: Body
	*/
	Payload *models.APIVersions `json:"body,omitempty"`
}

// NewListAPIVersionsOK creates ListAPIVersionsOK with default headers values
func NewListAPIVersionsOK() *ListAPIVersionsOK {
	return &ListAPIVersionsOK{}
}

// WithPayload adds the payload to the list Api versions o k response
func (o *ListAPIVersionsOK) WithPayload(payload *models.APIVersions) *ListAPIVersionsOK {
	o.Payload = payload
	return o
}

// SetPayload sets the payload to the list Api versions o k response
func (o *ListAPIVersionsOK) SetPayload(payload *models.APIVersions) {
	o.Payload = payload
}

// WriteResponse to the client
func (o *ListAPIVersionsOK) WriteResponse(rw http.ResponseWriter, producer runtime.Producer) {

	rw.WriteHeader(200)
	if o.Payload != nil {
		payload := o.Payload
		if err := producer.Produce(rw, payload); err != nil {
			panic(err) // let the recovery middleware deal with this
		}
	}
}

// ListAPIVersionsUnauthorizedCode is the HTTP code returned for type ListAPIVersionsUnauthorized
const ListAPIVersionsUnauthorizedCode int = 401

/*ListAPIVersionsUnauthorized Unauthorized

swagger:response listApiVersionsUnauthorized
*/
type ListAPIVersionsUnauthorized struct {
}

// NewListAPIVersionsUnauthorized creates ListAPIVersionsUnauthorized with default headers values
func NewListAPIVersionsUnauthorized() *ListAPIVersionsUnauthorized {
	return &ListAPIVersionsUnauthorized{}
}

// WriteResponse to the client
func (o *ListAPIVersionsUnauthorized) WriteResponse(rw http.ResponseWriter, producer runtime.Producer) {

	rw.WriteHeader(401)
}
